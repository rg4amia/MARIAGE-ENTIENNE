import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/subscription.dart';
import 'subscription_controller.dart';

/// Catalogue commercial : packs mariage d'un côté, abonnements
/// professionnels de l'autre. Un couple ne doit pas avoir à comprendre une
/// grille pensée pour les agences.
class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionController>();
    controller.loadPlans();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tarifs')),
      body: Obx(() {
        if (controller.isLoadingPlans.value && controller.plans.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        if (controller.plans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Impossible de charger les tarifs. Vérifiez votre connexion.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        final currentPlanId = controller.currentPlanId;
        final packs = controller.weddingPacks;
        final subscriptions = controller.subscriptions;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            _SectionHeader(
              title: 'Pour votre mariage',
              subtitle:
                  'Un paiement unique, valable jusqu\'au jour J. Pas '
                  'd\'abonnement à résilier.',
            ),
            const SizedBox(height: 16),
            for (final plan in packs) ...[
              _PlanCard(plan: plan, isCurrent: plan.id == currentPlanId),
              const SizedBox(height: 14),
            ],
            if (subscriptions.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Pour les wedding planners',
                subtitle:
                    'Plusieurs mariages en parallèle, facturés au mois ou à '
                    'l\'année.',
              ),
              const SizedBox(height: 16),
              for (final plan in subscriptions) ...[
                _PlanCard(plan: plan, isCurrent: plan.id == currentPlanId),
                const SizedBox(height: 14),
              ],
            ],
            const SizedBox(height: 12),
            Text(
              'Paiement par Orange Money, Wave, MTN MoMo ou Moov Money. '
              'Écrivez-nous pour activer un pack.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineMd.copyWith(color: AppColors.dark),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrent;

  const _PlanCard({required this.plan, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.dark,
          width: isCurrent ? 2 : 1.35,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: AppTextStyles.titleLg.copyWith(color: AppColors.dark),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Actuel',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                plan.formattedAmount,
                style: AppTextStyles.headlineLg.copyWith(
                  color: AppColors.primary,
                ),
              ),
              if (!plan.isFree) ...[
                const SizedBox(width: 6),
                Text(
                  plan.billingLabel,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          if (plan.description != null) ...[
            const SizedBox(height: 6),
            Text(
              plan.description!,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _PlanLine(
            label: plan.isWeddingPack
                ? 'Invités'
                : 'Invités par mariage',
            value: SubscriptionPlan.quotaLabel(plan.maxGuestsPerEvent),
          ),
          _PlanLine(
            label: 'Invitations envoyées',
            value: SubscriptionPlan.quotaLabel(plan.maxInvitations),
          ),
          if (!plan.isWeddingPack)
            _PlanLine(
              label: 'Mariages actifs',
              value: SubscriptionPlan.quotaLabel(plan.maxEvents),
            ),
          _PlanLine(
            label: 'Collaborateurs',
            value: SubscriptionPlan.quotaLabel(plan.collaborators),
          ),
          _PlanLine(
            label: 'Espace médias',
            value: '${(plan.maxStorageMb / 1024).toStringAsFixed(
              plan.maxStorageMb < 1024 ? 1 : 0,
            )} Go',
          ),
          if (plan.hasWatermark)
            _PlanLine(
              label: 'Carte d\'invitation',
              value: 'Avec filigrane',
            ),
          if (plan.hasHdExport)
            _PlanLine(label: 'Album vidéo', value: 'Export HD'),
        ],
      ),
    );
  }
}

class _PlanLine extends StatelessWidget {
  final String label;
  final String value;

  const _PlanLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_rounded, size: 17, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.dark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
