import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/wedding_header.dart';
import '../../data/models/guest.dart';
import '../../data/repositories/guest_link_repository.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../core/constants/supabase_config.dart';
import '../../core/utils/quota_error.dart';
import '../subscription/subscription_controller.dart';
import 'invitations_controller.dart';

class QrCodePage extends StatelessWidget {
  const QrCodePage({super.key});

  Future<String?> _getPublicUrl(
    Guest guest,
    InvitationsController controller,
  ) async {
    try {
      final links = GuestLinkRepository();
      final link =
          await links.getLinkByGuestId(guest.id) ??
          await links.createGuestLink(guest.id);
      if (link != null) return link.getInviteUrl(SupabaseConfig.url);
      return (await controller.getInvitationForGuest(guest.id))?.webUrl;
    } catch (error) {
      debugPrint('Impossible de générer le lien QR: $error');
      return null;
    }
  }

  /// Décompte l'envoi avant de partager : c'est la base qui autorise ou
  /// refuse, l'écran se contente de proposer le pack supérieur en cas de refus.
  Future<void> _share(Guest guest, InvitationsController controller) async {
    final url = await _getPublicUrl(guest, controller);
    if (url == null) return;

    final invitation = await controller.getInvitationForGuest(guest.id);
    if (invitation == null) {
      Get.snackbar(
        'Place à attribuer',
        'Placez ${guest.fullName.split(' ').first} à une table avant '
            'd\'envoyer son invitation.',
      );
      return;
    }

    final sent = await runWithQuotaGuard(() async {
      await InvitationRepository().recordDelivery(
        invitationId: invitation.id,
        destination: guest.phone,
      );
    });
    if (!sent) return;

    await Share.share(url);
    if (Get.isRegistered<SubscriptionController>()) {
      await Get.find<SubscriptionController>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Get.arguments == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(child: Text('Aucun invité fourni.')),
      );
    }

    final controller = Get.find<InvitationsController>();
    final guest = Get.arguments as Guest;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WeddingHeader(title: 'QR Code', trailing: const SizedBox(width: 40)),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dark accent top
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            color: AppColors.dark,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                guest.fullName,
                                style: AppTextStyles.headlineMd,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                guest.qrToken,
                                style: AppTextStyles.bodyMdOnVariant,
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.dark,
                                    width: 1.5,
                                  ),
                                ),
                                child: FutureBuilder(
                                  future: _getPublicUrl(guest, controller),
                                  builder: (context, snapshot) {
                                    final payload = snapshot.data;
                                    if (payload == null) {
                                      return const CircularProgressIndicator();
                                    }
                                    return QrImageView(
                                      data: payload,
                                      version: QrVersions.auto,
                                      size: 200,
                                      backgroundColor:
                                          AppColors.surfaceContainerLow,
                                      eyeStyle: QrEyeStyle(
                                        color: AppColors.dark,
                                      ),
                                      dataModuleStyle: QrDataModuleStyle(
                                        color: AppColors.dark,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              FutureBuilder(
                                future: controller.getInvitationForGuest(
                                  guest.id,
                                ),
                                builder: (context, snapshot) {
                                  final invitation = snapshot.data;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(color: AppColors.dark),
                                    ),
                                    child: Text(
                                      invitation?.invitationCode ??
                                          'INV-XXXX-XXXX',
                                      style: AppTextStyles.labelMd.copyWith(
                                        color: AppColors.dark,
                                        letterSpacing: 0.1,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _share(guest, controller),
                                      icon: const Icon(Icons.share),
                                      label: const Text('Partager'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.dark,
                                        side: BorderSide(
                                          color: AppColors.dark,
                                          width: 1.3,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final url = await _getPublicUrl(
                                          guest,
                                          controller,
                                        );
                                        if (url != null) {
                                          await Clipboard.setData(
                                            ClipboardData(text: url),
                                          );
                                          Get.snackbar(
                                            'Copié',
                                            'Lien d\'invitation copié',
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.copy),
                                      label: const Text('Copier'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
