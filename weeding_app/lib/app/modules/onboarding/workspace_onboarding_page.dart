import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
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
                  const SizedBox(height: 32),
                  Text(
                    'Créons votre espace mariage',
                    style: AppTextStyles.headlineLgMobile,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Un espace sécurisé pour votre équipe, vos lieux, vos '
                    'invités, vos cartes et votre plan de salle.',
                    style: AppTextStyles.bodyLg.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionCard(
                    title: 'Votre organisation',
                    child: TextField(
                      controller: controller.organizationNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l’organisation',
                        hintText: 'Ex. Mariage Aïcha & Karim',
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Le mariage',
                    child: Column(
                      children: [
                        TextField(
                          controller: controller.eventTitleController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Titre du mariage',
                            hintText: 'Ex. Le grand jour',
                            prefixIcon: Icon(Icons.favorite_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller.brideNameController,
                                textCapitalization: TextCapitalization.words,
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
                                controller: controller.groomNameController,
                                textCapitalization: TextCapitalization.words,
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
                        const SizedBox(height: 14),
                        Obx(() {
                          final date = controller.eventDate.value;
                          return InkWell(
                            onTap: () => _pickDate(context, controller),
                            borderRadius: BorderRadius.circular(16),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date prévue (facultatif)',
                                prefixIcon: Icon(Icons.calendar_month_rounded),
                              ),
                              child: Text(
                                date == null
                                    ? 'À définir plus tard'
                                    : MaterialLocalizations.of(
                                        context,
                                      ).formatMediumDate(date),
                                style: AppTextStyles.bodyLg,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Essai Pro de 14 jours : jusqu’à 3 mariages, '
                            '500 invités par mariage et 5 collaborateurs.',
                            style: AppTextStyles.bodyMd,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.createWorkspace,
                        icon: controller.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.arrow_forward_rounded),
                        label: Text(
                          controller.isLoading.value
                              ? 'Création en cours…'
                              : 'Créer mon espace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleLg),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
