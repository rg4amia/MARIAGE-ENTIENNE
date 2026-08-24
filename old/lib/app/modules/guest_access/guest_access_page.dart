import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/wedding_cards.dart';
import '../../core/widgets/wedding_top_bar.dart';
import '../../data/models/invitation_models.dart';
import '../../routes/app_routes.dart';
import 'guest_access_controller.dart';

/// Page "Bienvenue - Invite" reproduisant le design Stitch :
/// hero mosaic editorial, message de bienvenue serif, carte
/// Table/Place doree, CTA gradient bordeaux, signature E&M.
class GuestAccessPage extends StatelessWidget {
  const GuestAccessPage({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GuestAccessController(token), tag: token);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const WeddingTopBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final invitation = controller.invitation.value;
        if (invitation == null) {
          return const _NotFound();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroMosaic(invitation: invitation, controller: controller),
              const SizedBox(height: 40),
              const _WelcomeHeader(),
              const SizedBox(height: 20),
              _IntroText(controller: controller),
              const SizedBox(height: 28),
              _SeatCard(invitation: invitation),
              const SizedBox(height: 20),
              _InvitationStatusCard(invitation: invitation),
              const SizedBox(height: 32),
              _PrimaryActions(controller: controller, invitation: invitation),
              const SizedBox(height: 28),
              _MediaList(invitation: invitation),
              const SizedBox(height: 28),
              _CardSection(invitation: invitation, controller: controller),
              const SizedBox(height: 48),
              const EditorialDivider(),
              const SizedBox(height: 24),
              Text(
                '${controller.event.title} • ${controller.event.eventDateLabel} • Acces invite'
                    .toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  letterSpacing: 2.0,
                  color: AppColors.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Lien invalide',
              style: GoogleFonts.notoSerif(
                fontSize: 28,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cette invitation est introuvable ou a expiree.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMosaic extends StatelessWidget {
  const _HeroMosaic({required this.invitation, required this.controller});

  final GuestInvitation invitation;
  final GuestAccessController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: kWeddingGlow,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.85),
                    AppColors.primaryContainer.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  EyebrowLabel(
                    'Celebration exclusive',
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.guestName,
                        style: GoogleFonts.notoSerif(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        controller.event.subtitle,
                        style: GoogleFonts.manrope(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.surfaceContainerHighest,
                      boxShadow: kWeddingGlow,
                    ),
                    child: const Icon(
                      Icons.local_florist,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.primaryContainer,
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "L'amour est dans l'air".toUpperCase(),
                          style: GoogleFonts.manrope(
                            color: AppColors.secondaryContainer,
                            fontSize: 9,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Un moment\nsuspendu.',
                          style: GoogleFonts.notoSerif(
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
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

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const EyebrowLabel('Celebration exclusive'),
        const SizedBox(height: 12),
        Text(
          'Bienvenue a\nnotre Mariage !',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSerif(
            color: AppColors.primary,
            fontSize: 40,
            fontWeight: FontWeight.w700,
            height: 1.05,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 18),
        Container(width: 56, height: 1, color: AppColors.outlineVariant),
      ],
    );
  }
}

class _IntroText extends StatelessWidget {
  const _IntroText({required this.controller});

  final GuestAccessController controller;

  @override
  Widget build(BuildContext context) {
    return Text(
      kIsWeb
          ? "Pour debloquer votre invitation personnalisee, partagez un petit message audio ou video de minimum 30 secondes. Tout se passe directement dans votre navigateur."
          : "Pour debloquer votre invitation personnalisee, nous aimerions recevoir un petit message de votre part : audio ou video de 30 secondes minimum.",
      textAlign: TextAlign.center,
      style: GoogleFonts.manrope(
        fontSize: 15,
        height: 1.6,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}

class _SeatCard extends StatelessWidget {
  const _SeatCard({required this.invitation});

  final GuestInvitation invitation;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: Column(
        children: [
          const Icon(Icons.restaurant, color: AppColors.secondary, size: 28),
          const SizedBox(height: 14),
          const EyebrowLabel('Votre emplacement'),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SeatBlock(label: 'Table', value: invitation.tableLabel),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 22),
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
              ),
              _SeatBlock(label: 'Place', value: '${invitation.chairNumber}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeatBlock extends StatelessWidget {
  const _SeatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 9,
            letterSpacing: 1.6,
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.notoSerif(
            color: AppColors.primary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({required this.controller, required this.invitation});

  final GuestAccessController controller;
  final GuestInvitation invitation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GradientButton(
          label: invitation.isUnlocked
              ? 'Ajouter un autre media'
              : 'Commencer mon enregistrement',
          icon: invitation.isUnlocked ? Icons.check_circle : Icons.mic_rounded,
          expand: true,
          onPressed: () => Get.toNamed(
            AppRoutes.recording(invitation.token),
            arguments: invitation.token,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => controller.copyValue(
            invitation.webUrl,
            'Le lien web de votre invitation',
          ),
          icon: const Icon(Icons.link_rounded, size: 16),
          label: Text(
            'Copier mon lien web'.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 10,
              letterSpacing: 1.4,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InvitationStatusCard extends StatelessWidget {
  const _InvitationStatusCard({required this.invitation});

  final GuestInvitation invitation;

  @override
  Widget build(BuildContext context) {
    final status = invitation.guestStatus;
    final hasMedia = invitation.mediaSubmissions.isNotEmpty;

    return GlowCard(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('Etat backend'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaChip(
                icon: invitation.isUnlocked ? Icons.lock_open : Icons.lock,
                label: status.label,
              ),
              _MetaChip(
                icon: Icons.badge_outlined,
                label: 'Code ${invitation.invitationCode}',
              ),
              _MetaChip(
                icon: Icons.perm_media_outlined,
                label: hasMedia
                    ? '${invitation.mediaSubmissions.length} media(s)'
                    : 'Aucun media',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaList extends StatelessWidget {
  const _MediaList({required this.invitation});

  final GuestInvitation invitation;

  @override
  Widget build(BuildContext context) {
    if (invitation.mediaSubmissions.isEmpty) {
      return const SizedBox.shrink();
    }
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('Medias envoyes'),
          const SizedBox(height: 14),
          ...invitation.mediaSubmissions.map((media) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceContainerLow,
                    ),
                    child: Icon(
                      media.type == MediaType.audio
                          ? Icons.mic
                          : Icons.videocam,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${media.type.name.toUpperCase()} • ${media.clientDurationSeconds.toStringAsFixed(0)}s',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          media.isAccepted
                              ? 'Valide client + serveur'
                              : 'Refuse : duree insuffisante',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    media.isAccepted ? Icons.check_circle : Icons.error_outline,
                    color: media.isAccepted
                        ? AppColors.secondary
                        : AppColors.error,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.invitation, required this.controller});

  final GuestInvitation invitation;
  final GuestAccessController controller;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('Carte numerique'),
          const SizedBox(height: 12),
          Text(
            invitation.isUnlocked
                ? invitation.hasSignedCardAssets
                      ? 'Le backend a deja prepare des liens securises pour votre carte PNG/PDF.'
                      : 'Votre carte est debloquee. Vous pouvez generer une copie locale PNG/PDF depuis cette page.'
                : "La carte sera disponible des qu'un media valide aura ete envoye.",
            style: GoogleFonts.manrope(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          if (invitation.isUnlocked && invitation.hasSignedCardAssets) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (invitation.signedPngUrl?.isNotEmpty ?? false)
                  FilledButton(
                    onPressed: () => controller.copyValue(
                      invitation.signedPngUrl!,
                      'Le lien securise PNG',
                    ),
                    child: const Text('Copier le lien PNG'),
                  ),
                if (invitation.signedPdfUrl?.isNotEmpty ?? false)
                  OutlinedButton(
                    onPressed: () => controller.copyValue(
                      invitation.signedPdfUrl!,
                      'Le lien securise PDF',
                    ),
                    child: const Text('Copier le lien PDF'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: invitation.isUnlocked
                ? controller.exportUnlockedCard
                : null,
            child: Text(
              invitation.hasSignedCardAssets
                  ? 'Generer une copie locale'
                  : 'Telecharger la carte',
            ),
          ),
        ],
      ),
    );
  }
}
