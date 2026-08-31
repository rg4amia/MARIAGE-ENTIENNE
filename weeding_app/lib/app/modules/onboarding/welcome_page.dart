import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_widgets.dart';
import '../../routes/app_routes.dart';

/// Page de garde du SaaS : première chose que voit un visiteur sans compte.
///
/// Elle porte la promesse et l'ancrage tarifaire avant de proposer les deux
/// entrées du parcours — créer un mariage, ou se connecter.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeInSlide(
                delay: const Duration(milliseconds: 60),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.dark, width: 1.3),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 38,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mon Mariage',
                      style: AppTextStyles.headlineMd.copyWith(
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              FadeInSlide(
                delay: const Duration(milliseconds: 140),
                child: Text(
                  'Vos invitations de mariage,\nenvoyées en une soirée.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayMd.copyWith(
                    color: AppColors.dark,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeInSlide(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Placez vos invités, générez leurs cartes et suivez qui a '
                  'confirmé — depuis votre téléphone.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const _ValueProp(
                icon: Icons.event_seat_rounded,
                title: 'Un plan de salle qui se tient',
                detail: 'Tables, chaises et placement, sans double réservation.',
                delayMs: 260,
              ),
              const _ValueProp(
                icon: Icons.qr_code_2_rounded,
                title: 'Une carte et un QR code par invité',
                detail: 'Envoyés sur WhatsApp, scannés à l\'entrée le jour J.',
                delayMs: 320,
              ),
              const _ValueProp(
                icon: Icons.videocam_rounded,
                title: 'Un album de messages en cadeau',
                detail:
                    'Chaque invité enregistre 30 secondes pour débloquer sa '
                    'carte. Vous gardez l\'album.',
                delayMs: 380,
              ),
              const SizedBox(height: 28),
              FadeInSlide(
                delay: const Duration(milliseconds: 440),
                child: const _PriceAnchor(),
              ),
              const SizedBox(height: 28),
              FadeInSlide(
                delay: const Duration(milliseconds: 500),
                child: ElevatedButton(
                  onPressed: () => Get.toNamed(AppRoutes.register),
                  child: const Text('Créer mon mariage'),
                ),
              ),
              const SizedBox(height: 12),
              FadeInSlide(
                delay: const Duration(milliseconds: 540),
                child: OutlinedButton(
                  onPressed: () => Get.toNamed(AppRoutes.login),
                  child: const Text('J\'ai déjà un compte'),
                ),
              ),
              const SizedBox(height: 8),
              FadeInSlide(
                delay: const Duration(milliseconds: 580),
                child: TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.plans),
                  child: const Text('Voir les tarifs'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueProp extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final int delayMs;

  const _ValueProp({
    required this.icon,
    required this.title,
    required this.detail,
    required this.delayMs,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInSlide(
      delay: Duration(milliseconds: delayMs),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 21, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleLg.copyWith(
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le concurrent réel n'est pas une autre application, c'est le carton
/// imprimé : c'est à lui que le prix doit se comparer.
class _PriceAnchor extends StatelessWidget {
  const _PriceAnchor();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.dark, width: 1.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commencez gratuitement',
            style: AppTextStyles.titleLg.copyWith(color: AppColors.dark),
          ),
          const SizedBox(height: 6),
          Text(
            'Préparez tout votre mariage sans payer, et envoyez vos 30 '
            'premières invitations. Le pack 150 invités est à 35 000 F, '
            'une seule fois — pas d\'abonnement.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // L'ancrage est l'imprimeur, pas une autre application. Chiffre
          // volontairement bas de fourchette : voir docs/OFFRE_COMMERCIALE.md.
          Text(
            'À Abidjan, un carton imprimé coûte environ 500 F pièce. '
            'Avec le pack 300 invités, chaque invitation revient à 200 F.',
            style: AppTextStyles.labelMd.copyWith(color: AppColors.dark),
          ),
        ],
      ),
    );
  }
}
