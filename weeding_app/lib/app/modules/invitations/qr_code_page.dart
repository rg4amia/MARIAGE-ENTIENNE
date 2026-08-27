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
import '../../core/constants/supabase_config.dart';
import 'invitations_controller.dart';

class QrCodePage extends StatelessWidget {
  const QrCodePage({super.key});

  Future<String?> _getPublicUrl(
    Guest guest,
    InvitationsController controller,
  ) async {
    final links = GuestLinkRepository();
    final link =
        await links.getLinkByGuestId(guest.id) ??
        await links.createGuestLink(guest.id);
    if (link != null) return link.getInviteUrl(SupabaseConfig.url);
    return (await controller.getInvitationForGuest(guest.id))?.webUrl;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InvitationsController>();
    final guest = Get.arguments as Guest;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WeddingHeader(
            title: 'QR Code',
            trailing: const SizedBox(width: 40),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Gold accent top
                        Container(
                          height: 4,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.tertiaryFixed,
                                AppColors.secondaryFixed,
                              ],
                            ),
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
                                  color: AppColors.surfaceBright,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.tertiaryFixed,
                                    width: 2,
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
                                      backgroundColor: AppColors.surfaceBright,
                                      eyeStyle: const QrEyeStyle(
                                        color: AppColors.onSurface,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        color: AppColors.onSurface,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              FutureBuilder(
                                future: controller.getInvitationForGuest(guest.id),
                                builder: (context, snapshot) {
                                  final invitation = snapshot.data;
                                  return Text(
                                    invitation?.invitationCode ?? 'INV-XXXX-XXXX',
                                    style: AppTextStyles.labelMd.copyWith(
                                      letterSpacing: 0.1,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final url = await _getPublicUrl(guest, controller);
                                        if (url != null) await Share.share(url);
                                      },
                                      icon: const Icon(Icons.share),
                                      label: const Text('Partager'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.secondaryContainer,
                                        side: const BorderSide(color: AppColors.secondaryContainer, width: 2),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final url = await _getPublicUrl(guest, controller);
                                        if (url != null) {
                                          await Clipboard.setData(ClipboardData(text: url));
                                          Get.snackbar('Copié', 'Lien d\'invitation copié');
                                        }
                                      },
                                      icon: const Icon(Icons.copy),
                                      label: const Text('Copier'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
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
