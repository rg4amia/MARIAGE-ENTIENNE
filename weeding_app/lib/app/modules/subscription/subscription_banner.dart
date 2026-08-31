import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/subscription.dart';
import '../../routes/app_routes.dart';
import 'subscription_controller.dart';

/// Rappel du forfait sur le tableau de bord.
///
/// Il ne s'affiche que lorsqu'il a quelque chose à dire — quota bientôt
/// atteint, essai qui se termine, abonnement suspendu. Un bandeau permanent
/// finit par ne plus être lu.
class SubscriptionBanner extends StatelessWidget {
  const SubscriptionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionController>();

    return Obx(() {
      final overview = controller.overview.value;
      if (overview == null || !overview.shouldSuggestUpgrade) {
        return const SizedBox.shrink();
      }

      final message = _messageFor(overview);
      final isUrgent = overview.isBlocked || overview.invitationsLeft == 0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isUrgent ? AppColors.errorContainer : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUrgent ? AppColors.error : AppColors.primary,
              width: 1.35,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isUrgent
                        ? Icons.lock_outline_rounded
                        : Icons.auto_awesome_rounded,
                    size: 20,
                    color: isUrgent ? AppColors.error : AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Forfait ${overview.plan.name}',
                      style: AppTextStyles.titleLg.copyWith(
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.dark),
              ),
              if (overview.invitationsRatio != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: overview.invitationsRatio,
                    minHeight: 6,
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isUrgent ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.plans),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Voir les packs'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  String _messageFor(SubscriptionOverview overview) {
    if (overview.isBlocked) {
      return 'Votre forfait n\'est plus actif. Réactivez-le pour continuer à '
          'envoyer vos invitations.';
    }

    if (overview.guestsExceedPlan) {
      return 'Vous avez ${overview.usage.guests} invités, au-delà des '
          '${overview.plan.maxGuestsPerEvent} du forfait ${overview.plan.name}. '
          'Passez au pack supérieur pour tous les inviter.';
    }

    final left = overview.invitationsLeft;
    if (left == 0) {
      return 'Vos ${overview.plan.maxInvitations} invitations du forfait sont '
          'envoyées. Choisissez un pack pour continuer.';
    }

    final trialDays = overview.isTrialing ? overview.trialDaysLeft : null;
    if (trialDays != null && trialDays <= 7) {
      return trialDays <= 0
          ? 'Votre essai se termine aujourd\'hui.'
          : 'Il reste $trialDays jour${trialDays > 1 ? 's' : ''} d\'essai.';
    }

    return 'Il ne reste que $left invitation${left > 1 ? 's' : ''} à envoyer '
        'sur ce forfait.';
  }
}
